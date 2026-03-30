@IsTest
public class ALTaskControllerTest {

    // Helper to create a second active user we can assign tasks to
    private static User createAltUser() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'AltUser',
            Email = 'altuser' + System.currentTimeMillis() + '@test.com',
            Username = 'altuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'altu',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    private static Id getTaskRecordTypeIdByName(String rtName) {
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task'
              AND Name = :rtName
            LIMIT 1
        ];
        return rt.Id;
    }

    @IsTest
    static void getTasksTest() {
        Case c = new Case(Subject = 'getTasksTest');
        insert c;

        Id ecsRtId = getTaskRecordTypeIdByName('External Customer Support');
        Id hdRtId  = getTaskRecordTypeIdByName('Helpdesk');

        // Create two tasks for the case (one open, one completed)
        Task t1 = new Task(
            WhatId = c.Id,
            Subject = 'Open Task',
            Status = 'Not Started',
            RecordTypeId = ecsRtId
        );

        Task t2 = new Task(
            WhatId = c.Id,
            Subject = 'Completed Task',
            Status = 'Completed',
            RecordTypeId = hdRtId
        );

        insert new List<Task>{ t1, t2 };

        Test.startTest();
        List<Task> results = ALTaskController.getTasks(c.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'getTasks should return all tasks for the case');
    }

    @IsTest
    static void updateDetailsTest() {
        Case c = new Case(Subject = 'updateDetailsTest');
        insert c;

        Id ecsRtId = getTaskRecordTypeIdByName('External Customer Support');
        User alt = createAltUser();

        // Start the task owned by someone else and not completed
        Task t = new Task(
            WhatId = c.Id,
            Subject = 'To Complete',
            Status = 'Not Started',
            RecordTypeId = ecsRtId,
            OwnerId = alt.Id
        );
        insert t;

        Test.startTest();
        ALTaskController.updateDetails(new List<String>{ t.Id });
        Test.stopTest();

        Task afterT = [
            SELECT Status, OwnerId
            FROM Task
            WHERE Id = :t.Id
            LIMIT 1
        ];

        System.assertEquals('Completed', afterT.Status,
            'updateDetails should set Status to Completed');
        System.assertEquals(UserInfo.getUserId(), afterT.OwnerId,
            'updateDetails should assign task to the running user');
    }

    @IsTest
    static void updateTaskOwnerFromCaseIdTest() {
        Case c = new Case(Subject = 'updateTaskOwnerFromCaseIdTest');
        insert c;

        Id ecsRtId = getTaskRecordTypeIdByName('External Customer Support');
        User alt = createAltUser();

        // This ECS task should be reassigned (open)
        Task ecsOpen = new Task(
            WhatId = c.Id,
            Subject = 'ECS Open',
            Status = 'Not Started',
            RecordTypeId = ecsRtId,
            OwnerId = alt.Id
        );

        // This ECS task should NOT be reassigned (completed)
        Task ecsCompleted = new Task(
            WhatId = c.Id,
            Subject = 'ECS Completed',
            Status = 'Completed',
            RecordTypeId = ecsRtId,
            OwnerId = alt.Id
        );

        insert new List<Task>{ ecsOpen, ecsCompleted };

        Test.startTest();
        ALTaskController.updateTaskOwnerFromCaseId(c.Id);
        Test.stopTest();

        Map<Id, Task> afterMap = new Map<Id, Task>([
            SELECT Status, OwnerId
            FROM Task
            WHERE Id IN :new List<Id>{ ecsOpen.Id, ecsCompleted.Id }
        ]);

        System.assertEquals(UserInfo.getUserId(), afterMap.get(ecsOpen.Id).OwnerId,
            'Open ECS task should be assigned to running user');
        System.assertEquals(alt.Id, afterMap.get(ecsCompleted.Id).OwnerId,
            'Completed ECS task should not be changed');
    }
}