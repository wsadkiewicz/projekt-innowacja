public class MissingAnimal {
    @AuraEnabled public String id;
    @AuraEnabled public String missingDate;
    @AuraEnabled public String name;
    @AuraEnabled public String imageUrl;
    
    public MissingAnimal() {}
    
    public MissingAnimal(String id, String missingDate, String name, String imageUrl) {
        this.id = id;
        this.missingDate = missingDate;
        this.name = name;
        this.imageUrl = imageUrl;
    }
}