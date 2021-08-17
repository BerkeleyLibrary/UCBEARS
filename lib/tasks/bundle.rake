namespace :bundle do
  desc 'Updates the ruby-advisory-db then runs bundle-audit'
  task :audit do
    system 'bundle-audit check --update --ignore CVE-2015-9284 || true > log/audit.log'
  end
end
