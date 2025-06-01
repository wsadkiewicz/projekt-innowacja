public with sharing class CountingUnadoptedAnimals {
    public static void CountingUnadoptedAnimals(List<Adoption__c> adoptions) {
     Set<Id> animalIds = new Set<Id>();
        
        for (Adoption__c a : adoptions) {
            if (a.Animal__c != null) {
                animalIds.add(a.Animal__c);
            }
        }


        Map<Id, Animal__c> animals = new Map<Id, Animal__c>(
            [SELECT Id, Shelter__c FROM Animal__c WHERE Id IN :animalIds]
        );

        Set<Id> shelterIds = new Set<Id>();
        for (Animal__c a : animals.values()) {
            if (a.Shelter__c != null) {
                shelterIds.add(a.Shelter__c);
            }
        }

        List<Shelter__c> sheltersToUpdate = new List<Shelter__c>();

        for (Id shelterId : shelterIds) {
            List<Animal__c> shelterAnimals = [
                SELECT Id FROM Animal__c 
                WHERE Shelter__c = :shelterId
            ];

            Set<Id> animalIdsInShelter = new Set<Id>();
            for (Animal__c a : shelterAnimals) animalIdsInShelter.add(a.Id);

            
        }

        if (!sheltersToUpdate.isEmpty()) {
            update sheltersToUpdate;
        }
    }
}