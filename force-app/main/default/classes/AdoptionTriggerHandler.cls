public with sharing class AdoptionTriggerHandler extends TriggerHandler{

    public override void afterInsert(List<SObject> newList) {
        List<Adoption__c> adoptions = (List<Adoption__c>) newList;
        updatePoints(adoptions);
        updateAdoptions(adoptions, false);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(adoptions);
    }

    public override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Adoption__c> adoptions = (List<Adoption__c>) newList;
        Map<Id, Adoption__c> typedOldMap = (Map<Id, Adoption__c>) oldMap;
        updatePoints(adoptions);
        updateAdoptions(adoptions, false);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(adoptions);
        sendAdoptionStatusEmails(adoptions, typedOldMap);
    }

    public override void afterDelete(List<SObject> oldList) {
        List<Adoption__c> adoptions = (List<Adoption__c>) oldList;
        updateAdoptions(adoptions, true);
        CountingUnadoptedAnimals.CountingUnadoptedAnimals(adoptions);
    }


    public static void updatePoints(List<Adoption__c> Adoptions){
    Id realId = Schema.SObjectType.Adoption__c.getRecordTypeInfosByName().get('Real').getRecordTypeId();
    
    List<Account> accsToUpdate = new List<Account>();
    List<Account> accounts = new List<Account>();
    Map<Id, Integer> pointsToAdd = new Map<id, Integer>();

    for(Adoption__c adopt : Adoptions){
        if(adopt.Status__c == 'Approved'){
        Id accountId = adopt.Account__c;
        Integer newPoints = (adopt.RecordTypeId == realId) ? 20 : 10;
        Integer currPoints = pointsToAdd.get(accountId) ?? 0;
        pointsToAdd.put(accountId, currPoints + newPoints);
        }
    }
    
    accounts = [SELECT Id, Points__c FROM Account WHERE Id IN :pointsToAdd.keySet()];

    for (Account acc : accounts) {
        Integer pointsToAddNow = pointsToAdd.get(acc.Id);
        acc.Points__c = (acc.Points__c ?? 0) + pointsToAddNow;
        accsToUpdate.add(acc);
    }
    update accsToUpdate;
    }

    public static void updateAdoptions(List<Adoption__c> Adoptions, Boolean isDelete){
        
        Set<Id> animalsId = new Set<Id>();
        
        for(Adoption__c a : Adoptions){
            animalsId.add(a.Animal__c);
        }
        
        
        Map<Id, Shelter__c> shelterMap = new Map<Id, Shelter__c>();

			for (Animal__c a : [SELECT Id, Shelter__c, Shelter__r.Name, Shelter__r.Number_of_Adoptions__c
                    FROM Animal__c 
                    WHERE Id IN :animalsId AND Shelter__c != null]) {
    			shelterMap.put(a.Id, a.Shelter__r); 
}

        
        Map<Id, double> shelterAdoptionCounts = new Map<Id, double>();

        for(Adoption__c a : Adoptions){
            if(a.Status__c == 'Approved'){
            Shelter__c s = shelterMap.get(a.Animal__c);
            if(isDelete == true){
              shelterAdoptionCounts.put(s.Id, s.Number_of_Adoptions__c - 1);
            }else{
                shelterAdoptionCounts.put(s.Id, s.Number_of_Adoptions__c + 1);
            }
         
        	}
        }
        
        List<Shelter__c> sheltersToUpdate = new List<Shelter__c>();

        for(Id shelterId : shelterAdoptionCounts.keySet()){
            Shelter__c Shelter = new Shelter__c(Id = shelterId, Number_of_Adoptions__c = shelterAdoptionCounts.get(shelterId));
            sheltersToUpdate.add(Shelter);
		}
        
       update sheltersToUpdate; 
    }

    public static void CountingUnadoptedAnimals(List<Adoption__c> adoptions) {
     Set<Id> animalIds = new Set<Id>();
        
        for (Adoption__c a : adoptions) {
            if (a.Animal__c != null) {
                animalIds.add(a.Animal__c);
            }
        }


        Map<Id, Animal__c> animals = new Map<Id, Animal__c>(
            [SELECT Id, Shelter__c FROM Animal__c WHERE Id IN :animalIds]
        );

        Set<Id> shelterIds = new Set<Id>();
        for (Animal__c a : animals.values()) {
            if (a.Shelter__c != null) {
                shelterIds.add(a.Shelter__c);
            }
        }

        List<Shelter__c> sheltersToUpdate = new List<Shelter__c>();

        for (Id shelterId : shelterIds) {
            List<Animal__c> shelterAnimals = [
                SELECT Id FROM Animal__c 
                WHERE Shelter__c = :shelterId
            ];

            Set<Id> animalIdsInShelter = new Set<Id>();
            for (Animal__c a : shelterAnimals) animalIdsInShelter.add(a.Id);

            
        }

        if (!sheltersToUpdate.isEmpty()) {
            update sheltersToUpdate;
        }
    }

        private static final String EMAIL_TEMPLATE_NAME = 'ChangeAdoptionStatus';

    public static void sendAdoptionStatusEmails(List<Adoption__c> newList, Map<Id, Adoption__c> oldMap) {

        Set<Id> changedAdoptionIds = new Set<Id>();
        for (Adoption__c newAdoption : newList) {
            Adoption__c oldAdoption = oldMap.get(newAdoption.Id);
            if (newAdoption.Status__c != oldAdoption.Status__c && newAdoption.Account__c != null) {
                changedAdoptionIds.add(newAdoption.Id);
            }
        }

        if (changedAdoptionIds.isEmpty()) {
            return;
        }

        EmailTemplate template;
        try {
            template = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :EMAIL_TEMPLATE_NAME LIMIT 1];
        } catch (Exception e) {
            return;
        }

        Map<Id, Adoption__c> adoptionDataMap = new Map<Id, Adoption__c>([
            SELECT Id, Status__c, Account__c,
                   Animal__r.Name,
                   Account__r.PersonContactId,
                   Account__r.PersonContact.FirstName,
                   Account__r.PersonContact.LastName
            FROM Adoption__c 
            WHERE Id IN :changedAdoptionIds 
            AND Account__r.IsPersonAccount = true
            AND Account__r.PersonContactId != null
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id adoptionId : adoptionDataMap.keySet()) {
            Adoption__c adoptionWithData = adoptionDataMap.get(adoptionId);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(adoptionWithData.Account__r.PersonContactId);

            String templateBody = template.HtmlValue != null ? template.HtmlValue : template.Body;
            String customBody = modifyEmail(templateBody, adoptionWithData, adoptionWithData.Account__r.PersonContact);

            mail.setSubject(template.Subject);
            if (template.HtmlValue != null) {
                mail.setHtmlBody(customBody);
            } else {
                mail.setPlainTextBody(customBody);
            }

            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }
        } 
    }
    
    private static String modifyEmail(String originalBody, Adoption__c adoption, Contact contact) {
        String modifiedBody = originalBody;
        
        String FirstName = contact.FirstName;
        modifiedBody = modifiedBody.replace('{{{Recipient.FirstName}}}', FirstName);
        
        String LastName = contact.LastName;
        modifiedBody = modifiedBody.replace('{{{Recipient.LastName}}}', LastName);
        
        String animalName = adoption.Animal__r.Name;
        modifiedBody = modifiedBody.replace('{{{Adoption__c.Animal__r.Name}}}', animalName);
        
        String originalStatus = adoption.Status__c;
        modifiedBody = modifiedBody.replace('{{{Adoption__c.Status__c}}}', originalStatus);
        
        return modifiedBody;
    }

}