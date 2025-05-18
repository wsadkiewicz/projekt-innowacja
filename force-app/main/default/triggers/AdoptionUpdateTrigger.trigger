trigger AdoptionUpdateTrigger on Adoption__c (after insert, after update) {
	
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            CountigAdoptionHandler.updateAdoptions(Trigger.new);
        }
    }
    
}