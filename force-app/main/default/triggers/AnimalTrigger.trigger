trigger AnimalTrigger on Animal__c (after insert) {
    new AnimalTriggerHandler().run();
}