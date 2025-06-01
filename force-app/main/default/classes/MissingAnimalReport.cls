public class MissingAnimalReport {
    @AuraEnabled public String address;
    @AuraEnabled public Decimal disappearancePlaceLongitude;
    @AuraEnabled public Decimal disappearancePlaceLatitude;
    @AuraEnabled public String disappearanceDate;
    @AuraEnabled public String description;
    
    public MissingAnimalReport() {}
}