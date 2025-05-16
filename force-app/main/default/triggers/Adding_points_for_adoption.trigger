trigger Adding_points_for_adoption on Adoption__c (before insert){

    Id virtualId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Virtual').getRecordTypeId();
    Id realId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Real').getRecordTypeId();

    for (Adoption__c a : Trigger.new) {


        Integer points = 0;
        if (a.RecordTypeId == virtualId) {
            points = 10;
        } else if (a.RecordTypeId == realId) {
            points = 20;
        }

        if (points > 0) {
            Account acc = [SELECT Id, Points__c FROM Account WHERE Id = :a.Account__c];
            acc.Points__c = (acc.Points__c ?? 0) + points;
            update acc;
        }
    }
    //aktualizowanie poza forem
    //wyciagnac query poza petle
    //sprawdza czy realna adopcja jest done
    //updetowac wartosci zamist insertu
    //after insert
    //points defult 0, nie sprawdzac wartosci
    //linie 10-14 uproscic do jednej
}