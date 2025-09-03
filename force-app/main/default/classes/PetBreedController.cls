public with sharing class PetBreedController {
    @AuraEnabled(cacheable=true)
    public static List<String> getBreedOptions() {
        List<String> breedList = new List<String>();

        for (AggregateResult result : [
            SELECT Breed__c
            FROM Pet__c
            WHERE Breed__c != null
            GROUP BY Breed__c
            ORDER BY Breed__c
        ]) {
            breedList.add((String) result.get('Breed__c'));
        }

        return breedList;
    }
}