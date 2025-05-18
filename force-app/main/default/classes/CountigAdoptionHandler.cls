public class CountigAdoptionHandler {
	
    public static void updateAdoptions(List<Adoption__c> Adoptions){
        
        Set<Id> animalsId = new Set<Id>();
        
        for(Adoption__c a : Adoptions){
            animalsId.add(a.Animal__c);
            
        }
        
        List<Animal__c> animals = new List<Animal__c>();
        
        animals = [Select Id, Shelter__c from Animal__c where Animal__c.Id in : animalsId];
        
        Map<Id, Id> shelterMap = new Map<Id, Id>();

        for(Animal__c a : animals){
        	shelterMap.put(a.Id, a.Shelter__c);    
        }
        
        Set<Id> shelterIds = new Set<Id>();

        for(Adoption__c a : Adoptions){
            Id animalId = a.Animal__c;
            if(shelterMap.containsKey(animalId)){
                shelterIds.add(shelterMap.get(animalId));
            }
        }
        
        Map<Id, Integer> shelterAdoptionCounts = new Map<Id, Integer>();

        for(Adoption__c a : Adoptions){
            Id shelterId = shelterMap.get(a.Animal__c);
            if(shelterId != null){
                if(!shelterAdoptionCounts.containsKey(shelterId)){
                    shelterAdoptionCounts.put(shelterId, 1);
                } else {
                    shelterAdoptionCounts.put(shelterId, shelterAdoptionCounts.get(shelterId) + 1);
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