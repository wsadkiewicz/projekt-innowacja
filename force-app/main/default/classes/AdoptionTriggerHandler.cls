public with sharing class AdoptionTriggerHandler {
    public void handleAfterInsert(List<Adoption__c> Adoptions) {
        CountingAdoption.updateAdoptions(Adoptions, false);
        CountingPoints.updatePoints(Adoptions);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(Adoptions);
    }
    public void handleAfterUpdate(List<Adoption__c> Adoptions, Map<Id, Adoption__c> oldMap){
        CountingAdoption.updateAdoptions(Adoptions, false);
        CountingPoints.updatePoints(Adoptions);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(Adoptions);
        AdoptionEmailManager.sendAdoptionStatusEmails(adoptions, oldMap);
    }
    public void handleAfterDelete(List<Adoption__c> Adoptions){
        CountingAdoption.updateAdoptions(Adoptions, true);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(Adoptions);
    }
}