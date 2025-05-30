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
}