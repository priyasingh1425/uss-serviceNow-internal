/**
 * Created by Ladd Partners on 02/28/2025.
*/

public class lp_ProductSelector extends lp_Selector {
    public lp_ProductSelector() {
        setSObjectType(Product2.getSObjectType());
        addField(Product2.Id);
        addField(Product2.Name);
    }
    
    public Product2 getByName(String productName) {
    	Product2 product = null;
	    List<Product2> products = getByNames(new Set<String>{ productName });
        if(!products.isEmpty()) {
          product = products[0];
        }
    	return product;
  	}

  	public List<Product2> getByNames(Set<String> productNames) {
        String query = getSelectStatement();
        query += ' WHERE Name in :productNames';
        return Database.query(query);
  	}
}