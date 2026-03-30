@RestResource(urlMapping='/mpl/*')
global with sharing class CityIntegrationAPI {
    
    @HttpPost
    global static MPLResponse handlePost() {
        RestRequest req = RestContext.request;
        String action = req.params.get('apiAction');
        String body = req.requestBody.toString();

        if (String.isBlank(action)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Missing action parameter', false, 'POST', 'CityIntegrationAPI handlePost', 'false', '400', 'Error', null, null, null);
            return MPLResponse.error('Missing action parameter');
        }

        System.debug('Request Body: '+ body);

        String accId;
        String conId;
        if (action == 'createIncident' || action == 'createChangeRequest') {
            accId = CityIntegrationConstants.ACCOUNT_ID;
            if (accId == null) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Required account not configured in MPL Integration Settings', false, 'POST', 'CityIntegrationAPI handlePost', 'false', '500', 'Error', null, null, null);
                RestContext.response.statusCode = 500;
                return MPLResponse.error('Required account not configured in MPL Integration Settings');
            }
            List<Contact> cons = [SELECT Id FROM Contact WHERE Name = :CityIntegrationConstants.CONTACT_NAME LIMIT 1];
            if (cons.isEmpty()) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Required contact not found', false, 'POST', 'CityIntegrationAPI handlePost', 'false', '500', 'Error', null, null, null);
                RestContext.response.statusCode = 500;
                return MPLResponse.error('Required contact not found');
            }
            conId = cons[0].Id;
        }

        if (action == 'createIncident') {
            return processCreateIncident(req, body, accId, conId, action);
        } else if (action == 'createWorkNote') {
            return processCreateWorkNote(req, body, action);
        } else if (action == 'resolveIncident') {
            return processResolveIncident(req, body, action);
        } else if (action == 'reopenIncident') {
            return processReopenIncident(req, body, action);
        } else if (action == 'createChangeRequest') {
            return processCreateChangeRequest(req, body, accId, conId, action);
        }

        API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Unsupported POST action: ' + action, false, 'POST', 'CityIntegrationAPI handlePost', 'false', '400', 'Error', null, null, null);
        RestContext.response.statusCode = 400;
        return MPLResponse.error('Unsupported POST action: ' + action);
    }
    
    @HttpPatch
    global static MPLResponse handlePatch() {
        RestRequest req = RestContext.request;
        String action = req.params.get('apiAction');
        String body = req.requestBody.toString();

        if (String.isBlank(action)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Missing action parameter', false, 'PATCH', 'CityIntegrationAPI handlePatch', 'false', '400', 'Error', null, null, null);
            return MPLResponse.error('Missing action parameter');
        }
        
        System.debug('Request Body: '+ body);

        API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Unsupported PATCH action: ' + action, false, 'PATCH', 'CityIntegrationAPI handlePatch', 'false', '400', 'Error', null, null, null);
        return MPLResponse.error('Unsupported PATCH action: ' + action);
    }
    
    private static MPLResponse processCreateIncident(RestRequest req, String body, String accId, String conId, String action) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('External_Customer_Support').getRecordTypeId();
        MPLRequest.CreateIncident payload = (MPLRequest.CreateIncident) JSON.deserialize(body, MPLRequest.CreateIncident.class);
        Case c = new Case();
        c.Support_Queue__c = 'TOC Support';
        c.RecordTypeid = recordTypeId;
        c.Origin = 'API';
        c.Status = 'New';
        String mappedCategory = 'Standard';
        if (payload.Category != null && (payload.Category.equalsIgnoreCase('break fix') || payload.Category.equalsIgnoreCase('breakfix'))) {
            mappedCategory = 'Break/Fix';
        } else if (payload.Category != null && payload.Category.equalsIgnoreCase('service request')) {
            mappedCategory = 'Request';
        }
        c.Case_Type__c = mappedCategory;
        c.Description = payload.Description + '\n\nCategory: ' + (String.isNotBlank(payload.Category) ? payload.Category : '') + '\nSub-category: ' + (String.isNotBlank(payload.Subcategory) ? payload.Subcategory : '');
        c.Subject = payload.ShortDescription;
        c.Priority_Number__c = Integer.valueOf(payload.Priority);
        c.Priority = getPriorityValue(payload.Priority);
        c.Customer_Rec_Id__c = payload.APITicketID;
        c.AccountId = accId;
        c.ContactId = conId;

        if (String.isNotBlank(payload.APITicketID)) {
            List<Case> existing = [SELECT Id, CaseNumber FROM Case WHERE Customer_Rec_Id__c = :payload.APITicketID LIMIT 1];
            if (!existing.isEmpty()) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.incidentSuccess('Case already exists', String.valueOf(existing[0].Id), String.valueOf(existing[0].CaseNumber))), false, 'POST', 'CityIntegrationAPI createIncident', 'true', '200', 'Success', null, String.valueOf(existing[0].Id), null);
                return MPLResponse.incidentSuccess('Case already exists', String.valueOf(existing[0].Id), String.valueOf(existing[0].CaseNumber));
            }
        }

        Database.SaveResult caseSr = Database.insert(c, false);

        if (!caseSr.isSuccess()) {
            Database.Error err = caseSr.getErrors()[0];
            System.debug(LoggingLevel.ERROR, 'Case insert failed: ' + err.getStatusCode() + ' | ' + err.getMessage());
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, ErrorMessageBuilder.build(err), false, 'POST', 'CityIntegrationAPI createIncident', 'false', '400', 'Error', null, null, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error(ErrorMessageBuilder.build(err));
        }

        List<Case> incidentCases = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseSr.getId() LIMIT 1];
        API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.success('Case successfully created in Salesforce ' + action, String.valueOf(incidentCases[0].CaseNumber))), false, 'POST', 'CityIntegrationAPI createIncident', 'true', '200', 'Success', null, String.valueOf(incidentCases[0].Id), null);
        return MPLResponse.incidentSuccess('Case successfully created in Salesforce ' + action, String.valueOf(incidentCases[0].Id), String.valueOf(incidentCases[0].CaseNumber));
    }
    
    private static MPLResponse processCreateWorkNote(RestRequest req, String body, String action) {
        MPLRequest.CreateWorkNote payload = (MPLRequest.CreateWorkNote) JSON.deserialize(body, MPLRequest.CreateWorkNote.class);
        String parentId = payload.ParentRecID;
        String noteContent = payload.Details;

        if (String.isBlank(parentId)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id is required', false, 'POST', 'CityIntegrationAPI createWorkNote', 'false', '400', 'Error', null, null, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error('Parent Id is required');
        }

        if (!isValidSalesforceId(parentId)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Invalid Salesforce ID format', false, 'POST', 'CityIntegrationAPI createWorkNote', 'false', '400', 'Error', null, null, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error('Invalid Salesforce ID format');
        }
        
        List<Case> cases = [SELECT Id FROM Case WHERE Id = :parentId LIMIT 1];
        if (cases.isEmpty()) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id does not exist', false, 'POST', 'CityIntegrationAPI createWorkNote', 'false', '404', 'Error', null, parentId, null);
            RestContext.response.statusCode = 404;
            return MPLResponse.error('Parent Id does not exist');
        }
     
        if(noteContent != null && noteContent.startsWith('Work Notes from CTASK')) {
            System.debug('Entering CTASK logic...');
            String customerRecId = 'CTASK' + noteContent.substringAfter('CTASK').substringBefore(':');
            String workNoteDetails = noteContent.substringAfter(customerRecId+':').trim();
            System.debug('Entering CTASK Id parsed as: ' + customerRecId);
            if(customerRecId.length() > 1) {
                List<Case> childCaseList = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = :customerRecId and ParentId = :parentId LIMIT 1];
                if (childCaseList.isEmpty()) {
                    API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Change task not found: ' + customerRecId, false, 'POST', 'CityIntegrationAPI createWorkNote', 'false', '404', 'Error', null, parentId, null);
                    RestContext.response.statusCode = 404;
                    return MPLResponse.error('Change task not found: ' + customerRecId);
                }
                parentId = childCaseList[0].Id;
                noteContent = workNoteDetails;
                System.debug('CTASK set to: <<parentId,noteContent>> ' + '['+parentId+','+noteContent+']');
            }
            else {
                System.debug('Could not parse CTASK Id.');
            }
        }
        else {
            System.debug('No CTASK logic needed. [noteContent='+noteContent+']');
        }

        FeedItem note = new FeedItem();
        note.Body = noteContent;
        note.ParentId = parentId;
        note.Visibility = 'AllUsers';
        note.Type = 'TextPost';
        try {
            TriggerBypass.setBypassFeedItemTrigger(true);
            insert note;
            TriggerBypass.setBypassFeedItemTrigger(false);
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.success('Notes created successfully ' + action, String.valueOf(note.Id))), false, 'POST', 'CityIntegrationAPI createWorkNote', 'true', '200', 'Success', null, String.valueOf(note.Id), null);
            return MPLResponse.success('Notes created successfully ' + action, String.valueOf(note.Id), 'WORKNOTE');
        } catch (Exception e) {
            TriggerBypass.setBypassFeedItemTrigger(false);
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, e.getMessage(), false, 'POST', 'CityIntegrationAPI createWorkNote', 'false', '500', 'Error', null, parentId, null);
            RestContext.response.statusCode = 500;
            return MPLResponse.error('Failed to create work note: ' + e.getMessage());
        }
    }
    
    private static MPLResponse processResolveIncident(RestRequest req, String body, String action) {
        MPLRequest.ResolveIncident payload = (MPLRequest.ResolveIncident) JSON.deserialize(body, MPLRequest.ResolveIncident.class);
        
        if (String.isBlank(payload.IncidentRecID)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id is required', false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '400', 'Error', null, null, null);
            return MPLResponse.error('Parent Id is required');
        }

        if (!isValidSalesforceId(payload.IncidentRecID)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Invalid Salesforce ID format', false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '400', 'Error', null, null, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error('Invalid Salesforce ID format');
        }
        
        List<Case> cases = [SELECT Id, Status FROM Case WHERE Id = :payload.IncidentRecID LIMIT 1];
        if (cases.isEmpty()) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id does not exist', false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '404', 'Error', null, payload.IncidentRecID, null);
            RestContext.response.statusCode = 404;
            return MPLResponse.error('Parent Id does not exist');
        }
        
        if(cases[0].Status != null && cases[0].Status.equalsIgnoreCase('reopen')) {
            Case c = new Case();
            c.Id = payload.IncidentRecID;
            c.Details__c = payload.CloseDescription;
            c.Status = 'Resolved';
            try {
                Database.SaveResult sr = Database.update(c, false);
                
                if (!sr.isSuccess()) {
                    Database.Error err = sr.getErrors()[0];
                    API_APIResponse_INS.createAPIResponse(req.requestURI, body, ErrorMessageBuilder.build(err), false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '400', 'Error', null, String.valueOf(c.Id), null);
                    RestContext.response.statusCode = 400;
                    return MPLResponse.error(ErrorMessageBuilder.build(err));
                }
                
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.success('Case resolved successfully ' + action, String.valueOf(c.Id))), false, 'POST', 'CityIntegrationAPI resolveIncident', 'true', '200', 'Success', null, String.valueOf(c.Id), null);
                return MPLResponse.success('Case resolved successfully ' + action, String.valueOf(c.Id));
                
            } catch (Exception e) {
                System.debug('Exception: '+ e);
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, e.getMessage(), false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '500', 'Error', null, payload.IncidentRecID, null);
                RestContext.response.statusCode = 500;
                return MPLResponse.error('An unexpected system error occurred. Please contact support.');
            }
        }
        else {
            String errMsg = 'Unable to resolve due to current Case status ['+cases[0].Status+']. Can only resolve from "Reopen" status.';
            System.debug(errMsg);
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, errMsg, false, 'POST', 'CityIntegrationAPI resolveIncident', 'false', '400', 'Error', null, payload.IncidentRecID, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error(errMsg);
        }

    }
    
    private static MPLResponse processReopenIncident(RestRequest req, String body, String action) {
        MPLRequest.ReopenIncident payload = (MPLRequest.ReopenIncident) JSON.deserialize(body, MPLRequest.ReopenIncident.class);
        
        if (String.isBlank(payload.IncidentRecID)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id is required', false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '400', 'Error', null, null, null);
            return MPLResponse.error('Parent Id is required');
        }

        if (!isValidSalesforceId(payload.IncidentRecID)) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Invalid Salesforce ID format', false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '400', 'Error', null, null, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error('Invalid Salesforce ID format');
        }
        
        List<Case> cases = [SELECT Id, Status FROM Case WHERE Id = :payload.IncidentRecID LIMIT 1];
        if (cases.isEmpty()) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Parent Id does not exist', false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '404', 'Error', null, payload.IncidentRecID, null);
            RestContext.response.statusCode = 404;
            return MPLResponse.error('Parent Id does not exist');
        }

        String caseStatus = cases[0].Status != null ? cases[0].Status : '';
        if(caseStatus.equalsIgnoreCase('resolved') || caseStatus.equalsIgnoreCase('closed')) {
            Case c = new Case();
            c.Id = payload.IncidentRecID;
            c.Status = 'Reopen';
            try {
                Database.SaveResult sr = Database.update(c, false);
                if (!sr.isSuccess()) {
                    Database.Error err = sr.getErrors()[0];
                    API_APIResponse_INS.createAPIResponse(req.requestURI, body, ErrorMessageBuilder.build(err), false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '400', 'Error', null, String.valueOf(c.Id), null);
                    RestContext.response.statusCode = 400;
                    return MPLResponse.error(ErrorMessageBuilder.build(err));
                }
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.success('Case reopened successfully ' + action, String.valueOf(c.Id))), false, 'POST', 'CityIntegrationAPI reopenIncident', 'true', '200', 'Success', null, String.valueOf(c.Id), null);
                return MPLResponse.success('Case reopened successfully ' + action, String.valueOf(c.Id));
            } catch (Exception e) {
                System.debug('Exception: '+ e);
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, e.getMessage(), false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '500', 'Error', null, payload.IncidentRecID, null);
                RestContext.response.statusCode = 500;
                return MPLResponse.error('An unexpected system error occurred. Please contact support.');
            }
        }
        else {
            String errMsg = 'The Salesforce Case was not in a Resolved or Closed Status. ['+caseStatus+']';
            System.debug(errMsg);
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, errMsg, false, 'POST', 'CityIntegrationAPI reopenIncident', 'false', '400', 'Error', null, payload.IncidentRecID, null);
            RestContext.response.statusCode = 400;
            return MPLResponse.error(errMsg);
        }
    }
    
    private static MPLResponse processUpdateChangeRequestApproval(RestRequest req, String body, String SalesforceID, String status, String action) {
        try {
            if (String.isBlank(SalesforceID) || String.isBlank(status)) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'caseId and status are required', false, 'POST', 'CityIntegrationAPI updateChangeRequestApproval', 'false', '400', 'Error', null, null, null);
                RestContext.response.statusCode = 400;
                return MPLResponse.error('caseId and status are required');
            }

            if (!isValidSalesforceId(SalesforceID)) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Invalid Salesforce ID format', false, 'POST', 'CityIntegrationAPI updateChangeRequestApproval', 'false', '400', 'Error', null, null, null);
                RestContext.response.statusCode = 400;
                return MPLResponse.error('Invalid Salesforce ID format');
            }

            if (!'pending deployment'.equalsIgnoreCase(status.trim())) {
                String noActionMessage = 'No status update performed. Only Pending deployment status is supported.';
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.success(noActionMessage, SalesforceID)), false, 'POST', 'CityIntegrationAPI updateChangeRequestApproval', 'true', '200', 'Success', null, SalesforceID, null);
                return MPLResponse.success(noActionMessage, SalesforceID, 'CHANGE');
            }

            List<Case> changeRequests = [SELECT Id, CaseNumber FROM Case WHERE Id = :SalesforceID AND RecordType.DeveloperName = 'Change_Request' AND Origin != 'API' LIMIT 1];

            if (changeRequests.isEmpty()) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'Change request not found', false, 'POST', 'CityIntegrationAPI updateChangeRequestApproval', 'false', '404', 'Error', null, SalesforceID, null);
                RestContext.response.statusCode = 404;
                return MPLResponse.error('Change request not found');
            }

            List<Approval_Participants__c> customerApprovals = [SELECT Id, Status__c FROM Approval_Participants__c WHERE Case__c = :changeRequests[0].Id AND Approval_Type__c = 'Customer Approval'];

            if (customerApprovals.isEmpty()) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'No Customer Approval participant found for this change request', false, 'POST', 'CityIntegrationAPI updateChangeRequestStatus', 'false', '404', 'Error', null, String.valueOf(changeRequests[0].Id), null);
                RestContext.response.statusCode = 404;
                return MPLResponse.error('No Customer Approval participant found for this change request');
            }

            List<Approval_Participants__c> participantsToUpdate = new List<Approval_Participants__c>();
            for (Approval_Participants__c participant : customerApprovals) {
                if (participant.Status__c != 'Approved') {
                    participant.Status__c = 'Approved';
                    participantsToUpdate.add(participant);
                }
            }

            if (!participantsToUpdate.isEmpty()) {
                update participantsToUpdate;
            }

            String successMessage = participantsToUpdate.isEmpty()
                ? 'Customer Approval participant already in Approved status'
                : 'Customer Approval participant status updated to Approved ' + action;
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.successChange(successMessage, String.valueOf(changeRequests[0].CaseNumber), String.valueOf(changeRequests[0].Id))), false, 'POST', 'CityIntegrationAPI updateChangeRequestStatus', 'true', '200', 'Success', null, String.valueOf(changeRequests[0].Id), null);
            return MPLResponse.successChange(successMessage, String.valueOf(changeRequests[0].CaseNumber), String.valueOf(changeRequests[0].Id));
        } catch (Exception e) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, e.getMessage(), false, 'POST', 'CityIntegrationAPI updateChangeRequestStatus', 'false', '500', 'Error', null, null, null);
            RestContext.response.statusCode = 500;
            return MPLResponse.error('Failed to update change request status: ' + e.getMessage());
        }
    }

    private static MPLResponse processCreateChangeRequest(RestRequest req, String body, String accId, String conId, String action) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Change_Request').getRecordTypeId();
        try {
            List<Group> queues = [SELECT Id FROM Group WHERE Name = :CityIntegrationConstants.QUEUE_TOC AND Type = 'Queue' LIMIT 1];
            if (queues.isEmpty()) {
                API_APIResponse_INS.createAPIResponse(req.requestURI, body, 'TOC Queue not found', false, 'POST', 'CityIntegrationAPI createChangeRequest', 'false', '500', 'Error', null, null, null);
                RestContext.response.statusCode = 500;
                return MPLResponse.error('TOC Queue not found');
            }
            Id assignedToGroup = queues[0].Id;
            MPLRequest.CreateChangeRequest payload = (MPLRequest.CreateChangeRequest) JSON.deserialize(body, MPLRequest.CreateChangeRequest.class);

            if (String.isNotBlank(payload.SalesforceID)
                && String.isNotBlank(payload.State)
                && 'pending deployment'.equalsIgnoreCase(payload.State.trim())) {
                return processUpdateChangeRequestApproval(req, body, payload.SalesforceID, payload.State, action);
            }

            System.debug('payload.APIChangeID: '+ payload.APIChangeID);
            System.debug('payload '+ payload);
            List<Case> existingCases = new List<Case>();
            
            if (String.isNotBlank(payload.APIChangeID)) {
                existingCases = [SELECT Id, CaseNumber FROM Case WHERE Customer_Rec_Id__c = :payload.APIChangeID LIMIT 1];
            }
            
            Case insertedCase;
            Boolean caseAlreadyExists = false;
            
            if (!existingCases.isEmpty()) {
                System.debug('Inside existingCases: ');
                insertedCase = existingCases[0];
                caseAlreadyExists = true;
            } else {
                Case c = new Case();
                c.Support_Queue__c = 'TOC Support';
                c.RecordTypeId = recordTypeId;
                c.Origin = 'API';
                c.Status = 'New';
                c.Subject = payload.ShortDescription;
                c.Description = payload.Description;
                c.Customer_Rec_Id__c = payload.APIChangeID;
                c.Case_Type__c = 'Normal';
                c.Case_Classification__c = 'Configuration';
                if(payload.ScheduledStartDate != null){
                    c.Planned_Start_Date__c = DateTime.valueOf(payload.ScheduledStartDate);
                }
                if(payload.ScheduledEndDate != null){
                    c.Planned_Delivery_Date__c = DateTime.valueOf(payload.ScheduledEndDate);
                }
                if(payload.Priority != null){
                    c.Priority_Number__c = Integer.valueOf(payload.Priority);
                    c.Priority = getPriorityValue(payload.Priority);
                }
                c.AccountId = accId;
                c.ContactId = conId;
                
                Database.SaveResult caseSr = Database.insert(c, false);
                
                if (!caseSr.isSuccess()) {
                    Database.Error err = caseSr.getErrors()[0];
                    System.debug(LoggingLevel.ERROR, 'Case insert failed: ' + err.getStatusCode() + ' | ' + err.getMessage());
                    API_APIResponse_INS.createAPIResponse(req.requestURI, body, ErrorMessageBuilder.build(err), false, 'POST', 'CityIntegrationAPI createChangeRequest', 'false', '400', 'Error', null, null, null);
                    RestContext.response.statusCode = 400;
                    return MPLResponse.error(ErrorMessageBuilder.build(err));
                }
                
                insertedCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseSr.getId() LIMIT 1];
            }
            
            Set<String> existingChangeTaskIds = new Set<String>();
            if (payload.tasks != null && !payload.tasks.isEmpty()) {
                Set<String> incomingChangeTaskIds = new Set<String>();
                for (MPLRequest.ChangeRequestTask changeTaskPayload : payload.tasks) {
                    if (String.isNotBlank(changeTaskPayload.APITicketID)) {
                        incomingChangeTaskIds.add(changeTaskPayload.APITicketID);
                    }
                }

                if (!incomingChangeTaskIds.isEmpty()) {
                    List<Case> existingChangeTasks = [
                        SELECT Id, Customer_Rec_Id__c
                        FROM Case
                        WHERE Customer_Rec_Id__c IN :incomingChangeTaskIds
                        AND ParentId = :insertedCase.Id
                    ];

                    for (Case existingChangeTask : existingChangeTasks) {
                        existingChangeTaskIds.add(existingChangeTask.Customer_Rec_Id__c);
                    }
                }
            }

            List<Case> changeTasksToInsert = new List<Case>();
            if (payload.tasks != null && !payload.tasks.isEmpty()) {
                for (MPLRequest.ChangeRequestTask taskPayload : payload.tasks) {
                    if (String.isNotBlank(taskPayload.APITicketID)
                        && existingChangeTaskIds.contains(taskPayload.APITicketID)) {
                        continue;
                    }

                    Case ct = new Case();
                    ct.Support_Queue__c = 'TOC Support';
                    ct.RecordTypeId = recordTypeId;
                    ct.Subject = taskPayload.Title;
                    ct.Description = taskPayload.Description;
                    ct.ParentId = insertedCase.Id;
                    ct.OwnerId = assignedToGroup;
                    ct.Customer_Rec_Id__c = taskPayload.APITicketID;
                    ct.Origin = 'API';
                    ct.Status = 'New';
                    if(taskPayload.Priority != null){
                        ct.Priority_Number__c = Integer.valueOf(taskPayload.Priority);
                        ct.Priority = getPriorityValue(taskPayload.Priority);
                    }
                    if(taskPayload.ScheduledStartDate != null){
                        ct.Planned_Start_Date__c = DateTime.valueOf(taskPayload.ScheduledStartDate);
                    }
                    if(taskPayload.ScheduledEndDate != null){
                        ct.Planned_Delivery_Date__c = DateTime.valueOf(taskPayload.ScheduledEndDate);
                    }
                    ct.AccountId = accId;
                    ct.ContactId = conId;
                    ct.Case_Type__c = 'Normal';
                    changeTasksToInsert.add(ct);
                }
            }
            
            if (!changeTasksToInsert.isEmpty()) {
                List<Database.SaveResult> changeTaskResults = Database.insert(changeTasksToInsert, false);
                
                for (Database.SaveResult changeTaskSr : changeTaskResults) {
                    if (!changeTaskSr.isSuccess()) {
                        Database.Error err = changeTaskSr.getErrors()[0];
                        System.debug(LoggingLevel.ERROR, 'Change Task insert failed: ' + err.getStatusCode() + ' | ' + err.getMessage());
                        API_APIResponse_INS.createAPIResponse(req.requestURI, body, ErrorMessageBuilder.build(err), false, 'POST', 'CityIntegrationAPI createChangeRequest', 'false', '400', 'Error', null, String.valueOf(insertedCase.Id), null);
                        RestContext.response.statusCode = 400;
                        return MPLResponse.error(ErrorMessageBuilder.build(err));
                    }
                }
            }
            
            String successMessage = caseAlreadyExists ? 'Change request exists' : 'Change request created successfully';
            if(!changeTasksToInsert.isEmpty()) {
                successMessage += ' ['+changeTasksToInsert.size()+' change task'+(changeTasksToInsert.size()!=1?'s':'')+' created]';
            }
            successMessage += '. ';
            if (!existingChangeTaskIds.isEmpty()) {
                successMessage += 'Change Task'+(existingChangeTaskIds.size()!=1?'s':'')+' already exist'+(existingChangeTaskIds.size()!=1?'':'s')+' and '+(existingChangeTaskIds.size()!=1?'were':'was')+' skipped: ' + String.join(new List<String>(existingChangeTaskIds), ', ');
            }
            successMessage += ' ' + action;
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, JSON.serialize(MPLResponse.successChange(successMessage, insertedCase.CaseNumber, String.valueOf(insertedCase.Id))), false, 'POST', 'CityIntegrationAPI createChangeRequest', 'true', '200', 'Success', null, String.valueOf(insertedCase.Id), null);
            return MPLResponse.successChange(successMessage, insertedCase.CaseNumber, String.valueOf(insertedCase.Id));
        } catch (Exception e) {
            API_APIResponse_INS.createAPIResponse(req.requestURI, body, e.getMessage(), false, 'POST', 'CityIntegrationAPI createChangeRequest', 'false', '500', 'Error', null, null, null);
            RestContext.response.statusCode = 500;
            System.debug('e.get' + e.getMessage() + ' at '+ e.getlinenumber() + ' error ' + e);
            return MPLResponse.error('An unexpected system error occurred while processing the request. Please contact support.');
        }
    }



    private static Boolean isValidSalesforceId(String value) {
        try {
            Id.valueOf(value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static String getPriorityValue(String priority) {
        return CityIntegrationConstants.getPriorityLabel(priority);
    }
}