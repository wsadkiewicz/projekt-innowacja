public with sharing class AnimalFinderController {

    @AuraEnabled(cacheable=true)
    public static List<Animal__c> getAnimals(String shelterId, String breed, String ageRange, String sex) {
        String query = 'SELECT Id, Name, Breed__c, Age__c, Sex__c, Photo_Link__c,' +
                       'Shelter__c, Shelter__r.Name ' +
                       'FROM Animal__c ' +
                       'WHERE Status__c = \'Available\'';
        
        if (String.isNotBlank(shelterId)) {
            query += ' AND Shelter__c = :shelterId';
        }

        if (String.isNotBlank(breed)) {
            query += ' AND Breed__c = :breed';
        }
        
        if (String.isNotBlank(ageRange)) {
            switch on ageRange {
                when '0-2' {
                    query += ' AND Age__c <= 2';
                }
                when '3-5' {
                    query += ' AND Age__c >= 3 AND Age__c <= 5';
                }
                when '6-10' {
                    query += ' AND Age__c >= 6 AND Age__c <= 10';
                }
                when '10+' {
                    query += ' AND Age__c > 10';
                }
            }
        }

        if (String.isNotBlank(sex)) {
            query += ' AND Sex__c = :sex';
        }
        
        query += ' ORDER BY Name';
        
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Shelter__c> getShelters() {
        return [SELECT Id, Name FROM Shelter__c 
                ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getBreeds() {
        List<String> breeds = new List<String>();

        List<Schema.PicklistEntry> entries = Animal__c.Breed__c.getDescribe().getPickListValues();
        for (Schema.PicklistEntry entry : entries) {
            breeds.add(entry.getValue());
        }
        return breeds;
    }
}