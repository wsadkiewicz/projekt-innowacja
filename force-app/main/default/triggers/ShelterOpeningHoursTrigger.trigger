trigger ShelterOpeningHoursTrigger on Shelter__c (after insert) {
  if (Trigger.isAfter && Trigger.isInsert) {
        ShelterOpeningHoursController.createDefaultOpeningHours(Trigger.newMap.keySet());
   }
}