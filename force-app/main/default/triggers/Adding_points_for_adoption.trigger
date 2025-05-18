trigger Adding_points_for_adoption on Adoption__c (after insert){
    Id realId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Real').getRecordTypeId();
    
    List<Account> accsToUpdate = new List<Account>();
    List<Account> accounts = new List<Account>();
    Map<Id, Integer> pointsToAdd = new Map<id, Integer>();

    for(Adoption__c adopt : Trigger.new){
        if(adopt.Status__c == 'Approved'){
        Id accountId = adopt.Account__c;
        Integer newPoints = (adopt.RecordTypeId == realId) ? 20 : 10;
        Integer currPoints = pointsToAdd.containsKey(accountId) ? pointsToAdd.get(accountId) : 0;
        pointsToAdd.put(accountId, currPoints + newPoints);
        }
    }
    
    accounts = [SELECT Id, Points__c FROM Account WHERE Id IN :pointsToAdd.keySet()];

    for (Account acc : accounts) {
        Integer pointsToAddNow = pointsToAdd.get(acc.Id);
        acc.Points__c = (acc.Points__c == null ? 0 : acc.Points__c) + pointsToAddNow;
        accsToUpdate.add(acc);
    }
    update accsToUpdate;
}
// test
// test 2