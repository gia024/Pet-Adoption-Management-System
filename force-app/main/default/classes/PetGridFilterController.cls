public with sharing class PetGridFilterController {
    @AuraEnabled(cacheable=true)
    public static List<Pet__c> fetchFilteredPets(String breed, String gender, Integer minAge, Integer maxAge) {
        String query = 'SELECT Id, Name, Age__c, Breed__c, Gender__c, Image_URL__c FROM Pet__c WHERE Available__c = TRUE';
        
        if (String.isNotBlank(breed)) {
            query += ' AND Breed__c = :breed';
        }

        if (String.isNotBlank(gender)) {
            query += ' AND Gender__c = :gender';
        }

        if (minAge != null) {
            query += ' AND Age__c >= :minAge';
        }

        if (maxAge != null) {
            query += ' AND Age__c <= :maxAge';
        }

        query += ' ORDER BY Name';

        return Database.query(query);
    }
}