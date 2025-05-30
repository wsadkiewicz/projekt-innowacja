public class CountingAdoption{
	
    public static void updateAdoptions(List<Adoption__c> Adoptions, Boolean isDelete){
        
        Set<Id> animalsId = new Set<Id>();
        
        for(Adoption__c a : Adoptions){
            animalsId.add(a.Animal__c);
        }
        
        
        Map<Id, Shelter__c> shelterMap = new Map<Id, Shelter__c>();

			for (Animal__c a : [SELECT Id, Shelter__c, Shelter__r.Name, Shelter__r.Number_of_Adoptions__c
                    FROM Animal__c 
                    WHERE Id IN :animalsId AND Shelter__c != null]) {
    			shelterMap.put(a.Id, a.Shelter__r); 
}

        
        Map<Id, double> shelterAdoptionCounts = new Map<Id, double>();

        for(Adoption__c a : Adoptions){
            if(a.Status__c == 'Approved'){
            Shelter__c s = shelterMap.get(a.Animal__c);
            if(isDelete == true){
              shelterAdoptionCounts.put(s.Id, s.Number_of_Adoptions__c - 1);
            }else{
                shelterAdoptionCounts.put(s.Id, s.Number_of_Adoptions__c + 1);
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