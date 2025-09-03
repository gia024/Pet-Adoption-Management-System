public class PetHandler {
	
    private static final Boolean DEBUG = true;

    public static final String PAGE_ID = '727229410481397';

    @future(callout=true)
    public static void processImage(Id recordId, String richTextContent) {
        debugLog('processImage started for recordId: ' + recordId);

        try {
            debugLog('Rich text content: ' + richTextContent);

            // Extract refId from rich text
            Pattern p = Pattern.compile('refid=([^&"]+)');
            Matcher m = p.matcher(richTextContent);

            if (!m.find()) {
                debugLog('No refId found.');
                return;
            }

            String refId = m.group(1);
            debugLog('Extracted refId: ' + refId);

            // Build URL to fetch image blob
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String imageUrl = baseUrl + '/services/data/v64.0/sobjects/Pet__c/' + recordId + '/richTextImageFields/Pet_Image__c/' + refId;
            debugLog('Constructed image URL: ' + imageUrl);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(imageUrl);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            HttpResponse res = new Http().send(req);
            Blob imageBlob = res.getBodyAsBlob();
            debugLog('Fetched image blob size: ' + imageBlob.size());

            // Check if ContentVersion already exists for this Pet
            List<ContentVersion> existingCV = [
                SELECT Id 
                FROM ContentVersion 
                WHERE Title = :('Pet Image - ' + recordId)
                ORDER BY CreatedDate DESC LIMIT 1
            ];

            ContentVersion cv;
            if (!existingCV.isEmpty()) {
                cv = existingCV[0];
                debugLog('Existing ContentVersion found: ' + cv.Id); 
            } else {
                // Save new ContentVersion
                cv = new ContentVersion(
                    Title = 'Pet Image - ' + recordId,
                    PathOnClient = 'pet_image_' + recordId + '.jpg',
                    VersionData = imageBlob
                );
                insert cv;
                debugLog('Inserted ContentVersion: ' + cv.Id);
            }

            // Make the file publicly available
            ContentDistribution cd = new ContentDistribution(
                Name = 'Pet Public Image - ' + cv.Id,
                ContentVersionId = cv.Id,
                PreferencesAllowOriginalDownload = true,
                PreferencesLinkLatestVersion = true
            );
            insert cd;

            // Re-query to get the ContentDownloadUrl (direct raw file URL)
            cd = [SELECT ContentDownloadUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];

            String publicDownloadUrl = cd.ContentDownloadUrl;
            debugLog('Direct public download URL: ' + publicDownloadUrl);
			
            // Fetch Pet info for caption
            Pet__c pet = [SELECT Name, Breed__c, Age__c FROM Pet__c WHERE Id = :recordId LIMIT 1];
            String petName = pet.Name != null ? pet.Name : 'our new friend';
            String breed = pet.Breed__c != null ? pet.Breed__c : 'adorable pet';
            String ageStr = pet.Age__c != null ? String.valueOf(pet.Age__c) : '';

            // Build emoji-rich caption
            String caption = '🐾 Meet our adorable new friend! 🐶\n' +
                             'Say hello to' + petName + 'a playful ' + breed;
            if (ageStr != '') {
                caption += ', just ' + ageStr + ' years old';
            }
            caption += '! ❤️\nReady to find a loving home 🏡? Come visit us and make a new furry friend today! 🐕🐾';

            debugLog('Caption: ' + caption);
            
            // Queueable for Facebook
			System.enqueueJob(new FacebookPoster(publicDownloadUrl, caption));
			debugLog('Enqueued FacebookPoster for direct URL with caption: ' + publicDownloadUrl);

        } catch (Exception e) {
            debugLog('Error in processImage: ' + e.getMessage());
        }

        debugLog('processImage ended for recordId: ' + recordId);
    }

    private static void debugLog(String msg) {
        if (DEBUG) System.debug(msg);
    }
    
    // --- CMDT + Pet checkbox control ---
	public static void handleNewPetWithFacebook(Pet__c newPet) {
        // Get global CMDT record
    	Social_Post_Settings__mdt settings = Social_Post_Settings__mdt.getInstance('Pet_Post_Control');

        // Check both CMDT and pet-level checkbox
    	if (settings != null && settings.Post_to_Facebook__c && newPet.Post_to_Facebook__c) {
        	debugLog('Posting allowed. Calling processImage for Pet: ' + newPet.Id);
        	processImage(newPet.Id, newPet.Pet_Image__c);
    	} else {
        	debugLog('Facebook posting disabled by CMDT or pet-level checkbox for pet: ' + newPet.Name);
   	 }
	}

    // --- Queueable class for posting to Facebook ---
    public class FacebookPoster implements Queueable, Database.AllowsCallouts {
        private String publicUrl;
        private String caption;

        public FacebookPoster(String publicUrl, String caption) {
            this.publicUrl = publicUrl;
            this.caption = caption;
        }

        public void execute(QueueableContext ctx) {
            debugLog('### FacebookPoster started for URL: ' + publicUrl);
            try {
                // Test call to confirm Facebook API connection
                HttpRequest testReq = new HttpRequest();
                testReq.setEndpoint('callout:FacebookAPI/me?fields=id,name');
                testReq.setMethod('GET');
                Http testHttp = new Http();
                HttpResponse testRes = testHttp.send(testReq);
                debugLog('Facebook ME response: ' + testRes.getBody());

                // Then continue with your original photo POST
                String endpoint = 'callout:FacebookAPI/' + PAGE_ID +
                    '/photos?url=' + EncodingUtil.urlEncode(publicUrl, 'UTF-8') +
                    '&message=' + EncodingUtil.urlEncode(caption, 'UTF-8');

                debugLog('Facebook endpoint: ' + endpoint);

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');

                HttpResponse res = new Http().send(req);
                debugLog('Facebook response status: ' + res.getStatusCode());
                debugLog('Facebook response body: ' + res.getBody());

            } catch (Exception e) {
                debugLog('Error posting to Facebook: ' + e.getMessage());
            }
            debugLog('FacebookPoster ended for URL: ' + publicUrl);
        }

        private void debugLog(String msg) {
            if (DEBUG) System.debug(msg);
        }
    }
}