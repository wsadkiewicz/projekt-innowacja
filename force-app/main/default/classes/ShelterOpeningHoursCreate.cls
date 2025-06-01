public with sharing class ShelterOpeningHoursCreate {
    public static void createDefaultOpeningHours(Set<Id> shelterIds) {
        List<Opening_Hours__c> hoursToInsert = new List<Opening_Hours__c>();
        List<String> daysOfWeek = new List<String>{
            'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
        };

        for (Id shelterId : shelterIds) {
            for (String day : daysOfWeek) {
                Boolean isClosed = (day == 'Sunday'); 

    			Time openTime = isClosed ? null : Time.newInstance(9, 0, 0, 0);
    			Time closeTime = isClosed ? null : Time.newInstance(17, 0, 0, 0); 

    			hoursToInsert.add(new Opening_Hours__c(
                    Shelter__c = shelterId,
                    Day__c = day,
                    Open__c = openTime,
                    Close__c = closeTime,
                    Closed__c = isClosed
    			));
            }
        }

        if (!hoursToInsert.isEmpty()) {
            try {
                insert hoursToInsert;
            } catch (DmlException e) {
                System.debug('Error creating default opening hours: ' + e.getMessage());
            }
        }
    }
}