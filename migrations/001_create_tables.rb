Sequel.migration do
  up do
    create_table(:transactions) do
      Integer :id, :primary_key => true
      String :order_id                                                                                                                                                                                                                      
      Date   :date
      Float  :amount
      String :recv_account
      String :recv_bank_num
      String :c_symbol
      String :v_symbol
      String :s_symbol
      String :invoice
      Bool   :processed
    end

    create_table(:users) do
      primary_key :id
      String :name
      String :password
      Bool   :admin
    end

    create_table(:account) do
      Integer :id, :primary_key => true
      String  :currency
      Date    :update
      Integer :openingBalance
      Integer :closingBalance
      Float   :sumPositive
      Float   :sumNegative
    end
  end

  down do
    drop_table(:transactions)
    drop_table(:users)
    drop_table(:account)
  end
end
