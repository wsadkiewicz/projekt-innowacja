public with sharing class AnimalTriggerHandler {
    public void handleAfterInsert(List<Animal__c> Animals){
        AddingMissingAnimals.addingMissingAnimals(Animals);
        
    }
}