# Make sure that the .ssh directory exists in your server's user account home folder
mkdir C:\Users\username\.ssh\

# Use scp to copy the public key file generated previously on your client to the authorized_keys file on your server
Copy-Item .\id_rsa.pub $ENV:UserProfile\.ssh\authorized_keys
Pause