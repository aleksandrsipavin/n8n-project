# grant access to the user that you're currently logged in with for docker execution
sudo usermod -aG docker ${USER}
getent group | grep docker

echo "Log out and log back in, or run 'exec sg docker newgrp' to apply the group change."
