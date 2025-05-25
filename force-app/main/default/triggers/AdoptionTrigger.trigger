trigger AdoptionTrigger on Adoption__c (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            CountingAdoption.updateAdoptions(Trigger.new);
            CountingPoints.updatePoints(Trigger.new);
        }
        if(Trigger.isUpdate){
            CountingAdoption.updateAdoptions(Trigger.new);
            CountingPoints.updatePoints(Trigger.new);
        }
    }
}
