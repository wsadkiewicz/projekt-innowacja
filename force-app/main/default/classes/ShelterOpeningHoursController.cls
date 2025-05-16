public with sharing class ShelterOpeningHoursController {
    @AuraEnabled(cacheable=true)
    public static List<Opening_Hours__c> getOpeningHours(Id shelterId) {
        return [SELECT Day__c, Open__c, Close__c, Closed__c
                FROM Opening_Hours__c
                WHERE Shelter__c = :shelterId
                ORDER BY Day__c];
    }
}