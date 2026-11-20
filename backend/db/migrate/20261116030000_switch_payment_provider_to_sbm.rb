class SwitchPaymentProviderToSbm < ActiveRecord::Migration[8.0]
  def up
    change_column_default :payments, :provider, from: "maubank", to: "sbm"
    execute "UPDATE payments SET provider = 'sbm' WHERE provider = 'maubank'"
  end

  def down
    execute "UPDATE payments SET provider = 'maubank' WHERE provider = 'sbm'"
    change_column_default :payments, :provider, from: "sbm", to: "maubank"
  end
end
