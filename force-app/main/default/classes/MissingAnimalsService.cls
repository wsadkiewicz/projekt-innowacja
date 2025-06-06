public class MissingAnimalsService {

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
    
    @AuraEnabled(cacheable=true)
    public static List<MissingAnimal> getMissingAnimals(Integer dayDelta) {
        String token = MissingAnimalsAuthService.getAccessToken();
        
        if (token == null) return new List<MissingAnimal>();

        String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
        String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals';
        if (dayDelta != null && dayDelta > 0) {
            apiEndpoint += '?dayDelta=' + dayDelta;
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiEndpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() != 200) return new List<MissingAnimal>();
        
        try {
            List<MissingAnimal> animals = (List<MissingAnimal>) JSON.deserialize(
                response.getBody(), 
                List<MissingAnimal>.class
            );

            List<MissingAnimal> animalsWithImages = new List<MissingAnimal>();
            for (MissingAnimal animal : animals) {
                animalsWithImages.add(getAnimalById(animal.id, token));
            }
            return animalsWithImages;
        } catch (Exception e) {
            return new List<MissingAnimal>();
        }
    }
    
    private static MissingAnimal getAnimalById(String animalID, String token) {
        String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
        String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals/' + animalID;
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiEndpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() != 200) return null;
        
        try {
            MissingAnimal animal = (MissingAnimal) JSON.deserialize(
                response.getBody(), 
                MissingAnimal.class
            );
            return animal;
        } catch (Exception e) {
            return null;
        }
    }

    public class AnimalDetails {
        @AuraEnabled public String name;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public String breed;
        @AuraEnabled public Integer age;
        @AuraEnabled public String uniqueFeatures;
        @AuraEnabled public String size;
    }

    public class MissingAnimalReport {
        @AuraEnabled public String address;
        @AuraEnabled public Decimal disappearancePlaceLongitude;
        @AuraEnabled public Decimal disappearancePlaceLatitude;
        @AuraEnabled public String disappearanceDate;
        @AuraEnabled public String description;
    }


    public class MissingAnimalWrapper {
        @AuraEnabled public MissingAnimalReport report;
        @AuraEnabled public AnimalDetails animal;
    }

  	private static final String SUCCESS = 'Success';
    private static final String ERROR_AUTH = 'Null token';
    private static final String ERROR_MISSING_DATA = 'Missing data';
    private static final String ERROR_MISSING_LOCATION = 'Missing location';
    private static final String ERROR_MISSING_DATE = 'Missing date';
    private static final String ERROR_MISSING_DESCRIPTION = 'Missing description';
    private static final String ERROR_API = 'Api error';
    private static final String ERROR_EXCEPTION = 'Exception error';

    @AuraEnabled
    public static String createMissingAnimalReport(MissingAnimalWrapper missingAnimalWrapper) {
        String token = MissingAnimalsAuthService.getAccessToken();
        
        if (token == null) {
            return ERROR_AUTH;
        }
        
        if (missingAnimalWrapper?.report == null) {
            return ERROR_MISSING_DATA;
        }
        
        MissingAnimalReport report = missingAnimalWrapper.report;
        
        Boolean hasAddress = String.isNotBlank(report.address);
        Boolean hasCoordinates = (report.disappearancePlaceLongitude != null && 
                                report.disappearancePlaceLatitude != null);
        
        if (!hasAddress && !hasCoordinates) {
            return ERROR_MISSING_LOCATION;
        }
        if (String.isBlank(report.disappearanceDate)) {
            return ERROR_MISSING_DATE;
        }
        if (String.isBlank(report.description)) {
            return ERROR_MISSING_DESCRIPTION;
        }
        
        try {
            String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
            String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals';
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('missingAnimalWrapper', missingAnimalWrapper);
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + token);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(60000);
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 201) {
                return SUCCESS;
            } else {
                return ERROR_API + '_' + response.getStatusCode();
            }
        } catch (Exception e) {
            return ERROR_EXCEPTION;
        }
    }

    @AuraEnabled
    public static String updateAnimalFoundStatus(String animalId, Boolean found) {
        if (String.isBlank(animalId)) {
            return ERROR_MISSING_DATA;
        }
        
        String token = MissingAnimalsAuthService.getAccessToken();
        
        if (token == null) {
            return ERROR_AUTH;
        }
        
        try {
            String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
            String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals';
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('animalId', animalId);
            requestBody.put('found', found);
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setMethod('PUT');
            request.setHeader('Authorization', 'Bearer ' + token);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(60000);
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                return SUCCESS;
            } else {
                return ERROR_API + '_' + response.getStatusCode();
            }
        } catch (Exception e) {
            return ERROR_EXCEPTION;
        }
    }
}