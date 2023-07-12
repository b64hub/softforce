## Softrig x Salesforce Integration

**Development**

This project is using a scratch org development model. In order to contribute you will need to create a scratch org with and push all metadata configuration and code.

**Dependencies**

- sfdx cli
- sf cli
- sfpowerscripts ( npm install @dxatscale/sfpowerscripts)

A devcontainer with installed dependencies is provided.

**Scratch Org Setup**

For this you will need to be authenticated to a Dev Hub org - this is typically the Production Org

- Authenticate to the DevHub (Production Org)

  You need to perform this step only once

  ```
   $ sf force:auth:web:login -setalias devhub
  ```

- Clone the repository

- There are two options: fetch a scratch org with package dependencies pre-installed, or create an empty scratch org

  - Option A: Fetch a scratch org from the pool [Preferred]

    ```

    sfdx sfpowerscripts:pool:fetch -t dev -a  <alias>
    ```

  - Option B: Create a scratch org and install all dependencies

    ```
    sfdx force:org:create --definitionfile config/project-scratch-def.json --setalias <myScratchOrg> --targetdevhubusername <devhub-alias>
    sfdx sfpowerkit:package:dependencies:install --targetusername <myScratchOrg> -v <devhub-alias>

    Push the source code
    sfdx force:source:push --targetusername <myScratchOrg>

    ```

**File structure**

softforce

Contains the Apex Custom Auth Provider and remote site settings. Can be deployed as a unlocked package.

softforce-config

Source packaged metadata. Auth provider requires an Execution User which is org-specific. This can be configured through the env variable EXEC_USER before deployment.

src-temp

New metadata created in scratch orgs is automatically pulled to this location, and must be moved into a package as it does not get deployed.
