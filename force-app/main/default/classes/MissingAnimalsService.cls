public class MissingAnimalsService {
    
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

  	@AuraEnabled
    public static Boolean createMissingAnimalReport(MissingAnimalWrapper missingAnimalWrapper) {
        String token = MissingAnimalsAuthService.getAccessToken();
        
        if (token == null) {
            System.debug('Null token');
            return false;
        }
        
        if (missingAnimalWrapper?.report == null) {
            System.debug('Missing animal report is null');
            return false;
        }
        
        MissingAnimalReport report = missingAnimalWrapper.report;
        Boolean hasAddress = String.isNotBlank(report.address);
        Boolean hasCoordinates = (report.disappearancePlaceLongitude != null && 
                                report.disappearancePlaceLatitude != null);
        
        if (!hasAddress && !hasCoordinates) {
            System.debug('Missing address or coordinates');
            return false;
        }
        if (String.isBlank(report.disappearanceDate)) {
            System.debug('Missing disappearance date');
            return false;
        }
        if (String.isBlank(report.description)) {
            System.debug('Missing description');
            return false;
        }
        
        try {
            String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
            String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals';
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('missingAnimalWrapper', missingAnimalWrapper);
            String jsonBody = JSON.serialize(requestBody);
            
            System.debug('request body: ' + jsonBody);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + token);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(60000);
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            System.debug('Response status: ' + response.getStatusCode());
            System.debug('Response body ' + response.getBody());
            
            if (response.getStatusCode() == 201) {
                System.debug('Animal created successfully');
                return true;
            } else {
                System.debug('Error code: ' + response.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            System.debug('exception: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static Boolean updateAnimalFoundStatus(String animalId, Boolean found) {
        String token = MissingAnimalsAuthService.getAccessToken();
        
        if (token == null) {
            System.debug('Token is null');
            return false;
        }
        
        try {
            String instanceUrl = MissingAnimalsAuthService.getInstanceUrl();
            String apiEndpoint = instanceUrl + '/services/apexrest/MissingAnimals';
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('animalId', animalId);
            requestBody.put('found', found);
            String jsonBody = JSON.serialize(requestBody);
            
            System.debug('REQUEST BODY: ' + jsonBody);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setMethod('PUT');
            request.setHeader('Authorization', 'Bearer ' + token);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(60000);
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            System.debug('response status: ' + response.getStatusCode());
            System.debug('response body: ' + response.getBody());
            
            if (response.getStatusCode() == 200) {
                System.debug('Animal status updated successfully');
                return true;
            } else {
                System.debug('Error code: ' + response.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            System.debug('exception: ' + e.getMessage());
            return false;
        }
    }
}