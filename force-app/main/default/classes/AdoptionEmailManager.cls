public class AdoptionEmailManager {
    
    private static final String EMAIL_TEMPLATE_NAME = 'ChangeAdoptionStatus';
    
    public static void sendAdoptionStatusEmails(List<Adoption__c> newList, Map<Id, Adoption__c> oldMap) {
        System.debug('sendAdoptionStatusEmails started. Records to process: ' + newList.size());

        Set<Id> changedAdoptionIds = new Set<Id>();
        for (Adoption__c newAdoption : newList) {
            Adoption__c oldAdoption = oldMap.get(newAdoption.Id);
            if (newAdoption.Status__c != oldAdoption.Status__c && newAdoption.Account__c != null) {
                changedAdoptionIds.add(newAdoption.Id);
            }
        }

        if (changedAdoptionIds.isEmpty()) {
            System.debug('No adoptions with status changes found.');
            return;
        }

        EmailTemplate template;
        try {
            template = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :EMAIL_TEMPLATE_NAME LIMIT 1];
            System.debug('Email template found: ' + template.Id);
        } catch (Exception e) {
            System.debug('Error: Email template not found. ' + e.getMessage());
            return;
        }

        Map<Id, Adoption__c> adoptionWithDataMap = new Map<Id, Adoption__c>([
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
        for (Adoption__c newAdoption : newList) {
            Adoption__c oldAdoption = oldMap.get(newAdoption.Id);

            if (newAdoption.Status__c != oldAdoption.Status__c && 
                newAdoption.Account__c != null && 
                adoptionWithDataMap.containsKey(newAdoption.Id)) {

                Adoption__c adoptionWithData = adoptionWithDataMap.get(newAdoption.Id);
                
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
                    
        		//System.debug('Subject: ' + template.Subject);
        		//System.debug('Body: ' + customBody);
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('Emails sent successfully: ' + emails.size());
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }
        } else {
            System.debug('No emails to send.');
        }

        System.debug('sendAdoptionStatusEmails finished.');
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