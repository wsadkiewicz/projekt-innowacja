public with sharing class ShelterController {
    @AuraEnabled(cacheable=true)
    public static List<Shelter__c> getSheltersByCity(Id currentShelterId) {
        Shelter__c currentShelter = [SELECT Id, Name, Address__City__s
                                     FROM Shelter__c
                                     WHERE Id = :currentShelterId];
        
        List<Shelter__c> shelters = [SELECT Id, Name, Address__City__s, Address__CountryCode__s, Address__Street__s, Address__StateCode__s, Address__PostalCode__s
                                     FROM Shelter__c
                                     WHERE Address__City__s = :currentShelter.Address__City__s];
        
        return shelters;
    }
}