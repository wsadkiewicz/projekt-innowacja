public class AdoptionEmailManager {
    public static void sendAdoptionStatusEmails(List<Adoption__c> newList, Map<Id, Adoption__c> oldMap) {
        System.debug('sendAdoptionStatusEmails started. Records to process: ' + newList.size());

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'ChangeAdoptionStatus' LIMIT 1].Id;
            System.debug('Email template found: ' + templateId);
        } catch (Exception e) {
            System.debug('ERROR: Email template not found. ' + e.getMessage());
            return;
        }

        for (Adoption__c newAdoption : newList) {
            Adoption__c oldAdoption = oldMap.get(newAdoption.Id);

            if (newAdoption.Status__c != oldAdoption.Status__c && newAdoption.Account__c != null) {
                System.debug('Status changed for Adoption Id: ' + newAdoption.Id + ', sending email.');
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(newAdoption.Account__c);
                mail.setTemplateId(templateId);
                mail.setWhatId(newAdoption.Id);
                emails.add(mail);
            } 
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            System.debug('Emails sent: ' + emails.size());
        } else {
            System.debug('No emails to send.');
        }

        System.debug('sendAdoptionStatusEmails finished.');
    }
}