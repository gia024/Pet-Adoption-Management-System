trigger PetTrigger on Pet__c (after insert) {
    for (Pet__c pet : Trigger.new) {
        // Only process if the Pet_Image__c field is populated
        if (pet.Pet_Image__c != null) {
            // Call the new handler that checks CMDT + Pet checkbox
            PetHandler.handleNewPetWithFacebook(pet);
            System.debug('Checked CMDT + Pet checkbox and enqueued Facebook processing for Pet Id: ' + pet.Id);
        } else {
            System.debug('No Pet_Image__c found for Pet Id: ' + pet.Id);
        }
    }
}