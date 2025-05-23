trigger AdoptionUpdateTrigger on Adoption__c (after insert, after update) {
	
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            CountingAdoptionHandler.updateAdoptions(Trigger.new);
        }
    }
}
// zmiana nazwy na samo AdoptionTrigger
// zmiana nazwy klasy na CiuntigAdoption
// rozdziewlic ifa na isInsert i isUpdate i wywolywac metode