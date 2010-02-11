# Cookbook Name:: mongodb
# Recipe:: default

size = `curl -s http://instance-data.ec2.internal/latest/meta-data/instance-type`
package_tgz = case size
when /m1.small|c1.medium/ # 32 bit
  'mongodb-linux-i686-1.2.2.tgz'
else # 64 bit
  'mongodb-linux-x86_64-1.2.2.tgz'
end
package_folder = package_tgz.gsub('.tgz', '')

directory "/data/masterdb" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
  not_if { File.directory?('/data/masterdb') }
end

directory "/data/slavedb" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
  not_if { File.directory?('/data/slavedb') }
end
  
execute "install-mongodb" do
  # command %Q{
  #   curl -O http://downloads.mongodb.org/linux/#{package_tgz} &&
  #   tar zxvf #{package_tgz} &&
  #   mv #{package_folder} /usr/local/mongodb &&
  #   rm #{package_tgz}
  # }
  command %Q{
    curl -O http://downloads.mongodb.org/linux/#{package_tgz} &&
    tar zxvf #{package_tgz} &&
    mv #{package_folder} /usr/local/mongodb
  }
  not_if { File.directory?('/usr/local/mongodb') }
end
  
execute "add-to-path" do
  command %Q{
    echo 'export PATH=$PATH:/usr/local/mongodb/bin' >> /etc/profile
  }
  not_if "grep 'export PATH=$PATH:/usr/local/mongodb/bin' /etc/profile"
end
  
remote_file "/etc/init.d/mongodb" do
  source "mongodb"
  owner "root"
  group "root"
  mode 0755
end

execute "add-mongodb-to-default-run-level" do
  command %Q{
    rc-update add mongodb default
  }
  not_if "rc-status | grep mongodb"
end

execute "ensure-mongodb-is-running" do
  command %Q{
    /etc/init.d/mongodb start
  }
  not_if "pgrep mongod"
end