public class CountigAdoptionHandler {
	
    public static void updateAdoptions(List<Adoption__c> Adoptions){
        
        Set<Id> animalsId = new Set<Id>();
        
        for(Adoption__c a : Adoptions){
            animalsId.add(a.Animal__c);
        }
        
        
        Map<Id, Id> shelterMap = new Map<Id, Id>();

        for(Animal__c a : [Select Id, Shelter__c from Animal__c where Animal__c.Id in : animalsId]){
        	shelterMap.put(a.Id, a.Shelter__c);    
        }
        
        Map<Id, Integer> shelterAdoptionCounts = new Map<Id, Integer>();
        //pozbyc sie shelterId
        //wywalic if z nullem- odfiltrowac to w query
        //jezeli approved to ma zliczac
        //dodac do triggera after delete zeby zmiesjzczac ilosc apodpcji
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