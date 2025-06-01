trigger ShelterOpeningHoursTrigger on Shelter__c (after insert) {
  if (Trigger.isAfter && Trigger.isInsert) {
        ShelterOpeningHoursCreate.createDefaultOpeningHours(Trigger.newMap.keySet());
   }
}