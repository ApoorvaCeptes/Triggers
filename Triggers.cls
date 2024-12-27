   /**
    * Task 1
 * Fetches a map of accounts and their associated contacts based on the billing city "Bengaluru".
 * 
 * @description 
 * This method queries the Contact object to retrieve all contacts associated with accounts 
 * where the BillingCity is "Bengaluru". It then organizes the contacts into a map, 
 * where the key is the account ID (`AccountId`) and the value is a set of associated contacts. 
 * The method uses `WITH SECURITY_ENFORCED` to respect field-level security.
 * 
 * @returns {void}
 * Logs a map to the debug log, where:
 * - Key: Account ID (String)
 * - Value: A set of Contact records associated with the account.
 * 
 * @example
 * // Example usage:
 * // Call the method and check the debug log for results.
 * fetchAccountContacts();
 * 
 * @throws {Exception}
 * If an error occurs during the query or processing, the exception message is logged.
 */
public static void fetchAccountContacts() {
    Map<String,Set<Contact>> accountMap = new Map<String,Set<Contact>>();
    try {
        for(Contact con: [SELECT Id, FirstName, LastName,AccountId, Account.BillingCity FROM Contact WHERE Account.BillingCity = 'Bengaluru' WITH SECURITY_ENFORCED]) {
            String accId = con.AccountId;
            if(accountMap.containsKey(accId)) {
                accountMap.get(accId).add(con);
            }else {
               accountMap.put(accId , new Set<Contact>{con}); 
            }
        }
        System.debug(accountMap);
    }catch(Exception e) {
        System.debug(e.getMessage());
    } 
}

==================================================================
// Task 2 
// Trigger for Account object that fires after an Account record is updated
trigger AccountTrigger on Account (after update) {
    if(Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.afterUpdate((Map<Id,Account>)Trigger.newMap,(Map<Id,Account>)Trigger.oldMap);
    }
}

// Handler class for Account trigger logic
public class AccountTriggerHandler {

    /**
     * Executes logic after an Account record is updated.
     * @param newAccountMap - Map containing updated Account records (new values).
     * @param oldAccountMap - Map containing original Account records (old values).
     */
    public static void afterUpdate(Map<Id,Account> newAccountMap, Map<Id,Account> oldAccountMap) {
        updateContactMailingCity(newAccountMap,oldAccountMap);
    }

     /**
     * Updates the MailingCity field of related Contacts if the BillingCity of the Account has changed.
     * @param newAccountMap - Map containing updated Account records (new values).
     * @param oldAccountMap - Map containing original Account records (old values).
     */
    public static void updateContactMailingCity(Map<Id,Account> newAccountMap, Map<Id,Account> oldAccountMap) {
        // Map to store Account Ids and their updated BillingCity
        Map<Id,String> accCityMap = new Map<Id,String>();
        // Iterate through Account records to detect changes in BillingCity
        for(Id accId: newAccountMap.keySet()) {
            Account oldAccount = oldAccountMap.get(accId);
            Account newAccount = newAccountMap.get(accId);

            // Check if BillingCity has changed and is not blank
            if(String.isNotBlank(newAccount.BillingCity) && newAccount.BillingCity.equalsIgnoreCase(oldAccount.BillingCity)) {
                accCityMap.put(newAccount.Id,newAccount.BillingCity);
            }
        }
        // Query Contacts related to Accounts whose BillingCity has changed
        List<Contact> contacts = [Select Id, MailingCity, AccountId from Contact Where AccountId in :accCityMap.keySet()];
        // Update MailingCity of related Contacts
        for(Contact contact: contacts){
            contact.MailingCity = accCityMap.get(contact.AccountId);
        }
        // Perform DML update if there are Contacts to update
        if(!contacts.isEmpty()){
            update contacts;
        }
    }
}

