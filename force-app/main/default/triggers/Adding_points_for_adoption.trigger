trigger Adding_points_for_adoption on Adoption__c (before insert){

    Id virtualId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Virtual').getRecordTypeId();
    Id realId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Real').getRecordTypeId();

    for (Adoption__c a : Trigger.new) {
        if (a.Account__c == null) continue;

        Integer points = 0;
        if (a.RecordTypeId == virtualId) {
            points = 10;
        } else if (a.RecordTypeId == realId) {
            points = 20;
        }

        if (points > 0) {
            Account acc = [SELECT Id, Points__c FROM Account WHERE Id = :a.Account__c];
            acc.Points__c = (acc.Points__c == null ? 0 : acc.Points__c) + points;
            update acc;
        }
    }
}