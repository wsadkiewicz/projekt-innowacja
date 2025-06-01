public with sharing class ShelterOpeningHoursController {
    @AuraEnabled(cacheable=true)
    public static List<Opening_Hours__c> getOpeningHours(Id shelterId) {
        return [SELECT Day__c, Open__c, Close__c, Closed__c, Additional_Info__c
                FROM Opening_Hours__c
                WHERE Shelter__c = :shelterId];
    }

   @AuraEnabled
    public static void saveOpeningHours(List<Opening_Hours__c> openingHoursList, Id shelterId) {
        List<Opening_Hours__c> toUpdate = new List<Opening_Hours__c>();
        List<Opening_Hours__c> toInsert = new List<Opening_Hours__c>();

        for(Opening_Hours__c oh : openingHoursList) {
            validateOpeningHour(oh);

            if (oh.Id != null) {
                toUpdate.add(oh);
            } else {
                oh.Shelter__c = shelterId; 
                toInsert.add(oh);
            }
        }

        try {
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error saving opening hours: ' + e.getMessage());
        }
    }

    private static void validateOpeningHour(Opening_Hours__c oh) {
        if (!oh.Closed__c && oh.Open__c >= oh.Close__c) {
            throw new AuraHandledException('Open time must be before close time for ' + oh.Day__c);
        }
    }
}