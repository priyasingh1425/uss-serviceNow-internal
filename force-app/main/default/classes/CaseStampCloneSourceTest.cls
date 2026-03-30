@IsTest
private class CaseStampCloneSourceTest {

    @IsTest
    static void stampsCloneSourceOnClonedCase() {
        // Create the source Case
        Case sourceCase = new Case(
            Subject = 'Source Case',
            Status  = 'New',
            Origin  = 'Phone'
        );
        insert sourceCase;

        // Clone it (standard clone behavior)
        Case clonedCase = sourceCase.clone(false, true, false, false);
        clonedCase.Subject = 'Cloned Case';

        Test.startTest();
        insert clonedCase;
        Test.stopTest();

        // Re-query to ensure we see what was committed
        Case insertedClone = [
            SELECT Id, Cloned_From_Case__c
            FROM Case
            WHERE Id = :clonedCase.Id
            LIMIT 1
        ];

        System.assertEquals(
            sourceCase.Id,
            insertedClone.Cloned_From_Case__c,
            'Cloned_From_Case__c should be stamped with the original Case Id when the Case is cloned.'
        );
    }

    @IsTest
    static void doesNotOverwriteIfAlreadyStamped() {
        // True source that we will clone
        Case trueSource = new Case(
            Subject = 'True Source Case',
            Status  = 'New',
            Origin  = 'Phone'
        );
        insert trueSource;

        // Different Case Id we want to preserve as the already-stamped value
        Case preStampedSource = new Case(
            Subject = 'Pre-Stamped Source Case',
            Status  = 'New',
            Origin  = 'Phone'
        );
        insert preStampedSource;

        // Clone the true source
        Case clonedCase = trueSource.clone(false, true, false, false);
        clonedCase.Subject = 'Cloned But Already Stamped';

        // Pre-stamp with a different Id, handler should not overwrite
        clonedCase.Cloned_From_Case__c = preStampedSource.Id;

        Test.startTest();
        insert clonedCase;
        Test.stopTest();

        // Re-query and assert it was not overwritten
        Case insertedClone = [
            SELECT Id, Cloned_From_Case__c
            FROM Case
            WHERE Id = :clonedCase.Id
            LIMIT 1
        ];

        System.assertEquals(
            preStampedSource.Id,
            insertedClone.Cloned_From_Case__c,
            'Cloned_From_Case__c should not be overwritten if it is already populated before insert.'
        );
    }
}