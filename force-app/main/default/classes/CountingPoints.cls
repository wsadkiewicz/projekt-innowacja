public with sharing class CountingPoints{
    public static void updatePoints(List<Adoption__c> Adoptions){
    Id realId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Real').getRecordTypeId();
    
    List<Account> accsToUpdate = new List<Account>();
    List<Account> accounts = new List<Account>();
    Map<Id, Integer> pointsToAdd = new Map<id, Integer>();

    for(Adoption__c adopt : Adoptions){
        if(adopt.Status__c == 'Approved'){
        Id accountId = adopt.Account__c;
        Integer newPoints = (adopt.RecordTypeId == realId) ? 20 : 10;
        Integer currPoints = pointsToAdd.get(accountId) ?? 0;
        pointsToAdd.put(accountId, currPoints + newPoints);
        }
    }
    
    accounts = [SELECT Id, Points__c FROM Account WHERE Id IN :pointsToAdd.keySet()];

    for (Account acc : accounts) {
        Integer pointsToAddNow = pointsToAdd.get(acc.Id);
        acc.Points__c = (acc.Points__c ?? 0) + pointsToAddNow;
        accsToUpdate.add(acc);
    }
    update accsToUpdate;
    }
}