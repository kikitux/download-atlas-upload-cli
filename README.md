# download-hashicorp-tools

Simple scripts that download hashicorp applications

## For ruby `<file.rb>` packages

It requires `ruby` and `rubyzip` gem

For RH and friends: `yum install -y ruby rubygems && gem install rubyzip`

###Note
These scripts at the moment skip -rc version.
The reason behind this, is if you are faster testing a rc version, or building for master, you probably won't need these.
