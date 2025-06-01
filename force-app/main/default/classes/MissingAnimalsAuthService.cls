public class MissingAnimalsAuthService {

    public static Map<String, Object> getAuthData() {
        MissingAnimalsAuth__c authSettings = MissingAnimalsAuth__c.getInstance();
        
        if (authSettings == null) return null;
        
        String CLIENT_ID = authSettings.ClientID__c;
        String SECRET = authSettings.Secret__c;
        String USERNAME = authSettings.Username__c;
        String PASSWORD = authSettings.Password__c;
        String SECURITY_TOKEN = authSettings.SecurityToken__c;

        String tokenEndpoint = 'https://test.salesforce.com/services/oauth2/token';
        String fullPassword = PASSWORD + SECURITY_TOKEN;
        
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(tokenEndpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setTimeout(60000);
            
            request.setBody('grant_type=password'
                          + '&client_id=' + EncodingUtil.urlEncode(CLIENT_ID, 'UTF-8')
                          + '&client_secret=' + EncodingUtil.urlEncode(SECRET, 'UTF-8')
                          + '&username=' + EncodingUtil.urlEncode(USERNAME, 'UTF-8')
                          + '&password=' + EncodingUtil.urlEncode(fullPassword, 'UTF-8'));
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                return null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    public static String getAccessToken() {
        Map<String, Object> authData = MissingAnimalsAuthService.getAuthData();
        if (authData != null) {
            return (String) authData.get('access_token');
        }
        return null;
    }

    public static String getInstanceUrl() {
        Map<String, Object> authData = MissingAnimalsAuthService.getAuthData();
        if (authData != null) {
            return (String) authData.get('instance_url');
        }
        return null;
    }
}