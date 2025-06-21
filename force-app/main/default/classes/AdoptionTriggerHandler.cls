public with sharing class AdoptionTriggerHandler extends TriggerHandler{

    public override void afterInsert(List<SObject> newList) {
        List<Adoption__c> adoptions = (List<Adoption__c>) newList;
        updatePoints(adoptions);
        updateAdoptions(adoptions, false, null);
        CountingUnadoptedAnimals(adoptions, null);

    }

    public override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Adoption__c> adoptions = (List<Adoption__c>) newList;
        Map<Id, Adoption__c> typedOldMap = (Map<Id, Adoption__c>) oldMap;
        updatePoints(adoptions);
        updateAdoptions(adoptions, false, typedOldMap);
        CountingUnadoptedAnimals(adoptions, typedOldMap);
        sendAdoptionStatusEmails(adoptions, typedOldMap);
    }

    public override void afterDelete(List<SObject> oldList) {
        List<Adoption__c> adoptions = (List<Adoption__c>) oldList;
        updateAdoptions(adoptions, true, null);

        Map<Id, Adoption__c> oldMapForDel = new Map<Id, Adoption__c>();
        for (Adoption__c a : adoptions) oldMapForDel.put(a.Id, a);
        CountingUnadoptedAnimals(null, oldMapForDel);
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

    public static void updateAdoptions(List<Adoption__c> Adoptions, Boolean isDelete, Map<Id, Adoption__c> oldMap) {
    Set<Id> animalsId = new Set<Id>();
    for (Adoption__c a : Adoptions) {
        animalsId.add(a.Animal__c);
    }

    Map<Id, Animal__c> animals = new Map<Id, Animal__c>([
        SELECT Id, Shelter__c, Shelter__r.Number_of_Adoptions__c
        FROM Animal__c 
        WHERE Id IN :animalsId AND Shelter__c != null
    ]);

    Map<Id, Double> shelterAdoptionCounts = new Map<Id, Double>();

    for (Adoption__c a : Adoptions) {
        Animal__c animal = animals.get(a.Animal__c);
        if (animal == null) continue;

        Id shelterId = animal.Shelter__c;
        Double currentCount = animal.Shelter__r.Number_of_Adoptions__c ?? 0;

        if (isDelete) {
            if (a.Status__c == 'Approved') {
                shelterAdoptionCounts.put(shelterId, currentCount - 1);
            }
        } else {
            String oldStatus = oldMap?.get(a.Id)?.Status__c;
            //sprawdza czy został przekazany status czy null. Jezeli status dalej robi dalej get()...
            if (a.Status__c == 'Approved' && oldStatus != 'Approved') {
                shelterAdoptionCounts.put(shelterId, currentCount + 1);
            } else if (a.Status__c != 'Approved' && oldStatus == 'Approved') {
                shelterAdoptionCounts.put(shelterId, currentCount - 1);
            }
        }
    }
//uproscic ifa- sprawdzac tylko czy Status sie zmienil

    List<Shelter__c> sheltersToUpdate = new List<Shelter__c>();
    for (Id shelterId : shelterAdoptionCounts.keySet()) {
        sheltersToUpdate.add(new Shelter__c(Id = shelterId, Number_of_Adoptions__c = shelterAdoptionCounts.get(shelterId)));
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
    public static void CountingUnadoptedAnimals(List<Adoption__c> newList, Map<Id, Adoption__c> oldMap) {
        // 1) zbierz Id wszystkich zwierząt dotkniętych zmianami
        Set<Id> animalIds = new Set<Id>();
        if (newList != null) {
            for (Adoption__c a : newList) {
                if (a.Animal__c != null) animalIds.add(a.Animal__c);
            }
        }
        if (oldMap != null) {
            for (Adoption__c a : oldMap.values()) {
                if (a.Animal__c != null) animalIds.add(a.Animal__c);
            }
        }
        if (animalIds.isEmpty()) {
            return;
        }
        
        // 2) wyciągnij Id schronisk tych zwierząt
        Map<Id, Animal__c> animals = new Map<Id, Animal__c>(
            [SELECT Id, Shelter__c
             FROM Animal__c
             WHERE Id IN :animalIds
               AND Shelter__c != NULL]
        );
        Set<Id> shelterIds = new Set<Id>();
        for (Animal__c a : animals.values()) {
            shelterIds.add(a.Shelter__c);
        }
        if (shelterIds.isEmpty()) {
            return;
        }
        
        // 3a) zapytanie 1: total per shelter
        Map<Id,Integer> totalMap = new Map<Id,Integer>();
        for (AggregateResult ar : [
            SELECT Shelter__c S, COUNT(Id) cnt
            FROM Animal__c
            WHERE Shelter__c IN :shelterIds
            GROUP BY Shelter__c
        ]) {
            totalMap.put(
                (Id)ar.get('S'),
                (Integer)ar.get('cnt')
            );
        }
        
        // 3b) zapytanie 2: available+reserved per shelter
        Map<Id,Integer> availMap = new Map<Id,Integer>();
        for (AggregateResult ar : [
            SELECT Shelter__c S, COUNT(Id) cnt
            FROM Animal__c
            WHERE Shelter__c IN :shelterIds
              AND Status__c IN ('Available','Reserved')
            GROUP BY Shelter__c
        ]) {
            availMap.put(
                (Id)ar.get('S'),
                (Integer)ar.get('cnt')
            );
        }
        
        // 4) przygotuj listę do update
        List<Shelter__c> toUpdate = new List<Shelter__c>();
        for (Shelter__c sch : [
            SELECT Id, UnadoptedAnimals__c
            FROM Shelter__c
            WHERE Id IN :shelterIds
        ]) {
            Integer total  = totalMap.containsKey(sch.Id) ? totalMap.get(sch.Id) : 0;
            Integer avail  = availMap.containsKey(sch.Id) ? availMap.get(sch.Id) : 0;
            Integer newVal = total - avail;
            
            if (sch.UnadoptedAnimals__c == null 
                || sch.UnadoptedAnimals__c != newVal) {
                toUpdate.add(new Shelter__c(
                    Id = sch.Id,
                    UnadoptedAnimals__c = newVal
                ));
            }
        }
        
        // 5) wykonaj DML
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}