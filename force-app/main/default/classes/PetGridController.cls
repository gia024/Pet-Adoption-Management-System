public with sharing class PetGridController {
    @AuraEnabled(cacheable=true)
    public static List<Pet__c> fetchFilteredPets(String breed, String gender, Integer minAge, Integer maxAge) {
        String baseQuery = 'SELECT Id, Name, Breed__c, Gender__c, Age__c, Pet_Image__c, Description__c FROM Pet__c WHERE Status__c = \'Available\'';
        List<String> filters = new List<String>();

        if (String.isNotBlank(breed)) {
            filters.add('Breed__c = :breed');
        }
        if (String.isNotBlank(gender)) {
            filters.add('Gender__c = :gender');
        }
        if (minAge != null) {
            filters.add('Age__c >= :minAge');
        }
        if (maxAge != null) {
            filters.add('Age__c <= :maxAge');
        }

        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }

        return Database.query(baseQuery);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getBreedOptions() {
        Set<String> breedSet = new Set<String>();

        for (Pet__c pet : [
            SELECT Breed__c FROM Pet__c
            WHERE Breed__c != null AND Status__c = 'Available'
        ]) {
            breedSet.add(pet.Breed__c);
        }

        return new List<String>(breedSet);
    }
}