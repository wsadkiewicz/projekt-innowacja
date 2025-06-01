public with sharing class AnimalTirggerHandler {
    public void handleAfterInsert(List<Animal__c> Animals){
        AddingMissingAnimals.addingMissingAnimals(Animals);
        
    }
}