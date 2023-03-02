Web listing: `<datasets.server.mila.quebec>`_

Please fill this form to request a new dataset or a dataset to be migrated:
`<https://forms.gle/CNJEUZJs82qXJdYV7>`_

*******
Premise
*******

In the intention to better manage datasets used at Mila, we have set aside a
new volume with greater capacity to host your datasets (/network/datasets).
This volume will be managed, meaning that write access to the volume is
reserved to dedicated personnel. We therefore ask you to declare any datasets
you feel you need through this form : `<https://forms.gle/CNJEUZJs82qXJdYV7>`_.
One form should be filled per needed dataset. Alternatively, you can also send
a mail to helpdesk@mila.quebec who will ask you to fill in the form and follow
up on the process.

Amongst the objectives for this initiative are:

- Ensure immutability of given datasets
- Duplication management
- Provenance tracking
- Cleanup of doubtfully useful datasets
- More space for more datasets
- Tighter integration with batch scheduling tools and distribution throughout
  Mila accessible clusters.

**************************
Datasets Folders Structure
**************************

* | ``/``
  | Most datasets are located in the root of this repo but some might be nested
    in other directories. Datasets might have variant datasets which will be
    located in their ``DATASET.var`` directory
  | The script ``scripts/list_datasets.sh`` can be used to list all available
    datasets

* | ``/parlai``
  | Contains ParlAI ready datasets
  | The script w/ arg ``scripts/list_datasets.sh --parlai`` can be used to
    list the available datasets

* | ``/tensorflow``
  | Contains TensorFlow ready datasets
  | The script w/ arg ``scripts/list_datasets.sh --tensorflow`` can be used to
    list the available datasets

* | ``/torchvision``
  | Contains Torchvision ready datasets such as
    ``torchvision.datasets.DATASET(root="/network/datasets/torchvision"[, ...])``
    would load the dataset if it is available.
  | The script w/ arg ``scripts/list_datasets.sh --torchvision`` can be used to
    list the available datasets

* | ``/restricted``
  | Contains datasets with restricted access, often because of license
    requirements

Datasets which follow Digital Research Alliance of Canada's (DRAC) `good
practices on data
<https://docs.alliancecan.ca/wiki/AI_and_Machine_Learning#Managing_your_datasets>`_
are mirrored to the Alliance clusters in
``~/projects/rrg-bengioy-ad/data/curated/``. To list the local datasets on an
Alliance cluster, you can execute the following command:

.. prompt:: bash $

   ssh [DRAC_CLUSTER_LOGIN] -C "projects/rrg-bengioy-ad/data/curated/list_datasets_cc.sh"

Please refer to `<https://docs.mila.quebec/Information.html#datasets>`_ for
more details on the datasets storage
