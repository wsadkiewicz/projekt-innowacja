public class CountingAdoption{
	
    public static void updateAdoptions(List<Adoption__c> Adoptions, Boolean isDelete){
        
        Set<Id> animalsId = new Set<Id>();
        
        for(Adoption__c a : Adoptions){
            animalsId.add(a.Animal__c);
        }
        
        
        Map<Id, Id> shelterMap = new Map<Id, Id>();

        for(Animal__c a : [Select Id, Shelter__c from Animal__c where Animal__c.Id in : animalsId AND Shelter__c != null]){
        	shelterMap.put(a.Id, a.Shelter__c);    
        }
        
        Map<Id, Integer> shelterAdoptionCounts = new Map<Id, Integer>();

        //dodac do triggera after delete zeby zmiesjzczac ilosc apodpcji
        System.debug('przed petla');
        for(Adoption__c a : Adoptions){
            System.debug('nie weszlo do ifa');
            if(a.Status__c == 'Approved'){
                System.debug('weszlo do ifa');
            if(!shelterAdoptionCounts.containsKey(shelterMap.get(a.Animal__c))){
                shelterAdoptionCounts.put(shelterMap.get(a.Animal__c), 1);
                continue;
            if(isDelete == true){
              shelterAdoptionCounts.put(shelterMap.get(a.Animal__c), shelterAdoptionCounts.get(shelterMap.get(a.Animal__c)) - 1);
            }else{
                shelterAdoptionCounts.put(shelterMap.get(a.Animal__c), shelterAdoptionCounts.get(shelterMap.get(a.Animal__c)) + 1);
            }
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
    
}