public with sharing class AnimalTriggerHandler extends TriggerHandler{
     public override void afterInsert(List<SObject> newList) {
        List<Animal__c> animals = (List<Animal__c>) newList;
        addingMissingAnimals(animals);
        
    }

    public static void addingMissingAnimals(List<Animal__c> animals) {

        Set<Id> shelterIds = new Set<Id>();
        for (Animal__c a : animals) {
            if (a.Shelter__c != null) {
                shelterIds.add(a.Shelter__c);
            }
        }

        Map<Id, Shelter__c> shelterMap = new Map<Id, Shelter__c>(
            [SELECT Id, UnadoptedAnimals__c FROM Shelter__c WHERE Id IN :shelterIds]
        );

        Map<Id, double> countMap = new Map<Id, double>();
        for (Animal__c a : animals) {
            if (a.Shelter__c != null) {
                if (!countMap.containsKey(a.Shelter__c)) {
                    countMap.put(a.Shelter__c, 0);
                }
                countMap.put(a.Shelter__c, countMap.get(a.Shelter__c) + 1);
            }
        }

        List<Shelter__c> sheltersToUpdate = new List<Shelter__c>();
        for (Id shelterId : countMap.keySet()) {
            Shelter__c s = shelterMap.get(shelterId);
            double currentCount = (s.UnadoptedAnimals__c == null) ? 0 : s.UnadoptedAnimals__c;
            s.UnadoptedAnimals__c = currentCount + countMap.get(shelterId);
            sheltersToUpdate.add(s);
        }

        update sheltersToUpdate;
    }
}